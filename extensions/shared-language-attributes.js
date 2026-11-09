// Showroom v1.4.2 injects user_data into the first content source (English).
// Language versions share that environment, but retain their own attributes.
module.exports.register = function () {
  this.once('contentClassified', ({ contentCatalog }) => {
    for (const component of contentCatalog.getComponents()) {
      const english = component.versions.find(({ version }) => version === 'en')
      if (!english?.asciidoc?.attributes) continue
      for (const translated of component.versions) {
        if (translated === english) continue
        translated.asciidoc = {
          ...translated.asciidoc,
          attributes: {
            ...english.asciidoc.attributes,
            ...translated.asciidoc?.attributes,
          },
        }
      }
    }
  })
}
